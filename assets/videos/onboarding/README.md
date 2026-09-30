# Onboarding clips

Four short looping clips, one per carousel slide. Drop the files in with these
exact names — `onboarding_carousel_screen.dart` refers to them directly:

| File              | Slide                                        |
|-------------------|----------------------------------------------|
| `creators.mp4`    | "Your Favorite Creators Are the New Stylists" |
| `tap_try_buy.mp4` | "Tap. Try. Buy. Just Like That With Vibe Try" |
| `squads.mp4`      | "Find Your Tribe, Make Your Squad"            |
| `rewards.mp4`     | "Get Rewarded for Being Stylish"              |

Until a file exists the slide shows its still illustration from
`assets/images/onboarding/`, which is also what it falls back to if a clip
cannot be decoded. Nothing breaks while these are missing.

## What the clips need to be

* **Short and looping.** Three to six seconds. They loop forever, so the last
  frame should sit comfortably next to the first.
* **Silent.** Played at volume zero and there is no unmute control, so anything
  on the audio track is dead weight in the bundle.
* **Square.** Drawn into a 240x240 box with `BoxFit.cover`, so a non-square
  clip gets cropped on its long axis.
* **Small.** These ship inside the app and every byte is download size on the
  App Store listing. Aim for well under 1 MB each — H.264, and resolution no
  higher than 480x480, which is already more than a 240pt box can show.

Bundled rather than streamed on purpose: onboarding is the first screen a new
user sees, and it must not wait on a network or on a third party. See the
comments in `onboarding_clip.dart` for why reels were not used here.
