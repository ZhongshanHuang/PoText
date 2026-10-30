# Rendering on feature1

This implementation preserves the public APIs from `feature1`, including the
`PoText` builder, UIKit-style configuration, batched `configure`, truncation,
highlight callbacks, and `sizeToFit` layout promotion. It selectively migrates
the rendering improvements previously developed against the older `main`.

## Ownership and concurrency

`PoLabel` prepares an immutable `PoTextRenderRequest` on MainActor. Its source
is either a text/container snapshot, a completed reusable layout, or empty.
Cached redraws do not copy the text. The request captures bitmap size, scale,
dynamic-color traits, alignment, and animation settings.

Each `PoAsyncLayer` lazily owns a `PoTextRenderer` actor. Requests for that layer
execute serially; separate labels can render concurrently. Rendering returns an
immutable `PoTextRenderResult` instead of updating a shared mutable context.
The synchronous path uses the same rendering function without an actor hop.

Before committing, the main actor checks cancellation, the display generation,
and delegate identity. Empty/zero-size displays clear immediately. Cancellation
is checked before layout/allocation, between draw passes, and before commit.
TextKit calls already in progress cannot be interrupted; cancelled results are
discarded. This does not impose a global concurrency or memory limit.

The internal CALayer subclass bridges its nonisolated overrides into MainActor
with an explicit `@unchecked Sendable` carrier. Its mutable task, generation,
and UI state remain main-actor isolated. TextLayout separately serializes
drawing, hit testing, and its first attributed-string snapshot because TextKit
retains mutable internal state. Public layouts finish their drawing metadata
before publication; the TextKit objects remain internal.

Foundation attributes can contain arbitrary reference objects. Snapshots copy
the string, container paths, and truncation token, but cannot deeply freeze
every custom attribute. Callers must keep custom reference attributes and
attachment content stable while a layout is in use.

## Attachments and cancellation

Image attachments draw on the worker. UIView/CALayer attachments are hosted
only on MainActor. Hosting and bookkeeping are reconciled when pixels commit,
so cancelled requests cannot remove a newer request's attachments or lose
tracking of currently displayed controls.

With `isClearedContentsBeforeAsynchronouslyDisplay`, preclear removes both
the bitmap and hosted objects. Without preclear, the old pixels and controls
remain together until the replacement commits.

Fit native controls before creating an attachment and omit `size:` to reserve
their fitted bounds. Historical fixed dimensions can be smaller than current
controls. The old main Demo reserved 51 x 31 for UISwitch; the tested iOS 27
control fits to 63 x 28. The feature1 Demo uses fitted sizing. Regression tests
cover repeated shrinking/growing, text/control separation, truncation-token
separation, and removal of attachments excluded by the new layout.

## Measurement and reuse

Measurement uses the same shaping and truncation path as rendering, but skips
line records, border geometry, and attachment placement. The cache keeps a
size and width/content revision. Ordinary queries release the temporary
TextKit graph instead of retaining a second completed layout.

If the fitted width exactly equals the requested width, a private measurement
candidate is retained for feature1's existing `sizeToFit` promotion. Its
drawing metadata is completed before it becomes the render layout. Candidates
with a different width, changed content, or intervening geometry changes are
not promoted. Measurement queries never replace the displayed layout.

Foreground-color changes preserve measured geometry, discard any candidate
with old colors, invalidate the public string snapshot, and rebuild the render
layout. Text, font, paragraph, and container changes invalidate measurement.
Vertical alignment continues to redraw a reusable layout.

## feature1 performance comparison

The baseline is feature1 commit `09a61e9`, with the same benchmark sources and
attachment regression coverage as the migrated version. Measurements use
Xcode 27.0, iOS 27.0, an iPhone 18 Pro simulator, Release configuration, and
the median of eight XCTest samples. Loop timings are for the whole loop.

| Case | Before | After |
| --- | ---: | ---: |
| 100 color changes followed by same-width measurement | 95.160 ms | 0.101 ms |
| 25 alternating-width measurements with borders and 40 images | 44.354 ms | 17.655 ms |
| Long-text layout | 7.949 ms | 8.014 ms |
| Middle-truncation layout | 10.331 ms | 10.413 ms |
| Border-heavy layout | 3.199 ms | 3.229 ms |
| Image-attachment layout | 1.705 ms | 1.699 ms |

The measurement cases demonstrate cache reuse and eliminated drawing-metadata
work. They do not measure bitmap drawing or scrolling. The other layout cases
are effectively unchanged in this run. These simulator timings are diagnostic;
they do not establish real-device frame time or peak memory usage.

Run the opt-in benchmarks with Release tests and
`ENABLE_TESTABILITY=YES OTHER_SWIFT_FLAGS=-DPOTEXT_RUN_PERFORMANCE_TESTS`.
Normal runs skip the seven performance tests and have no timing thresholds.
Functional coverage includes public API compatibility, Unicode truncation,
measurement promotion, dynamic colors, source snapshots, rapid cancellation,
shared-layout concurrency, attachment hosting, and native-control geometry.

Validation of the migrated source passed 89 functional tests in Release and
under Thread Sanitizer, all seven opt-in performance tests, and the Demo build.
The installed Demo was also checked by dragging its resize handle, toggling
the native switch, and tapping the custom more token to expand the full text.

Previous measurements obtained on main are not feature1 benchmarks.
