# Course content

Every course has its own directory. Each directory contains sequential JSON modules:

```
assets/content/
  courses.json
  pytorch/
    module_0.json     # Core concepts
    module_1.json     # Tensors, Shapes & Memory
    ...
    module_6.json     # Checkpoints, Distribution & Capstone
    module_7.json     # Applied labs
    interview.json    # Separate question bank
  prompt_engineering/
    module_0.json     # Prompting Techniques & Control
    module_1.json     # Instruction Design & Evaluation
    module_2.json     # Task Specifications & Success Criteria
    ...
    module_7.json     # Reliability, Boundaries & Capstone
    interview.json    # Separate question bank
```

All 40 learning courses are registered in `courses.json`. Each course also has an
`interview.json` question bank, loaded on demand by `InterviewPrepRepository`.
Interview questions do not appear in course modules or contribute to lesson completion.
`AssetCurriculumLoader` reads this manifest at startup and loads each course through
`JsonTrackLoader`. These loaded modules replace the legacy seed modules. New course
Dart files contain display metadata only, not lesson content.

## Editing content

1. Edit the course's `module_N.json` files directly.
2. Keep filenames sequential from `module_0.json`.
3. When adding a module, update the course's `moduleCount` in `courses.json`.
4. When adding a directory, register it in `pubspec.yaml` under `flutter.assets` and
   add its folder, track ID, ID prefix and module count to `courses.json`.
5. Keep lesson and question IDs stable: saved progress and bookmarks reference them.

Existing JSON uses `idPrefix` plus the raw JSON `id`. Migrated modules and lessons
can supply `stableId` to preserve their existing IDs exactly, including when a
lesson moves between courses. Do not change these IDs just to match a filename.

A module contains `id`, `title`, `description` and `lessons`. Lessons use
`content.sections`, `quiz.questions`, and optional exercises. The loader also
supports explicit playgrounds, mini-projects, debugging challenges, interview
answers, project links and XP rewards. Quiz options may use the original string
array with `correctAnswer`, or objects with `id`, `text` and `isCorrect`.

Production loading is strict: missing or invalid registered files report an error
instead of silently reverting to older course content. Run `flutter test` after
content or manifest changes.

## Deterministic Interview Prep

Each `interview.json` defines questions with stable IDs, `format`, `category`,
`prompt`, `referenceAnswer`, `keyPoints` and `followUpIds`. Objective items include
`choices` and `correctIds`; code-output items include `code` and `expectedOutput`.
Ordering keys specify the exact sequence of choice IDs. Follow-ups form an acyclic
predefined graph and never depend on interpretation of typed text.

The `pools` object fixes the question sequence for `practice`, `interview`,
`rapidFire` (20 questions), `scenario`, and `mock` (10 questions). Edit these assets
to change questions or expected answers; no prompts, API keys or model services
are involved. All formats and answer keys are validated by the repository tests.

Free-text practice uses a self-marked checklist that locks when the reference is
revealed. Objective formats use exact answer keys. Skips are unscored; practice
mode does not score visible answers. Summaries store on the device, separately
from course progress. Typed responses are session-only and never transmitted.

## Expanded specialist courses

The 13 courses from PyTorch through Prompt Engineering each contain eight learning
modules. The first 12 contain 30 lessons each; Prompt Engineering contains 32.
The expansion adds 78 modules and 312 lessons with explanations, worked examples,
practice tasks and knowledge checks. Time estimates include the practice task.
Existing lesson and module IDs remain stable; the original specialist labs now
live in `module_7.json`. Prompt Engineering retains its first two modules.
Each expanded course also has six new interview scenarios with predefined
follow-ups in its separate `interview.json` bank.
