# Curriculum evolution

The library and course map now offer five overlapping career tracks. Course IDs remain stable, numeric ordering is no longer displayed, and daily time does not truncate career paths. Prerequisites are recommended preparation rather than global locks.

Twelve compact specialist courses add 36 concept lessons and 36 guided external labs. These are introductory learning units, not an assertion that the entire recommended advanced syllabus is complete. The portfolio catalog adds twelve specialist briefs and a production-platform capstone (21 projects total). External labs and portfolio completion remain self-assessed.

The experiment screen contains live mathematical attention, cosine similarity and inference-memory exercises. Its estimates explicitly exclude runtime overhead; it does not fabricate throughput measurements or claim to generate real sentence embeddings.

Profile skill evidence shows passed-quiz coverage separately from self-reported project completion. Verified coding/debugging/project grading remains future work; existing completion data must not be silently converted into mastery scores.

Course scope descriptions distinguish representation theory from database operations and ecosystem PEFT usage from fine-tuning decisions. Historical lesson content is retained to preserve progress. A full editorial removal of overlapping historical material remains future work.

## Technical references checked September 9, 2026

- PyTorch autograd and evaluation modes: https://docs.pytorch.org/docs/main/notes/autograd.html
- Transformer KV caching: https://huggingface.co/docs/transformers/main/kv_cache
- DeepSpeed ZeRO stage configuration: https://www.deepspeed.ai/docs/config-json/

Further depth still needed includes full per-topic specialist syllabi, actual PyTorch execution, a measured RAG chunking sandbox, and independently evaluated portfolio submissions.

## Course modules update

The catalog now contains 40 courses. Every course receives one Interview Questions module with three practice rounds, source-based model answers and follow-up prompts. The modules are generated after JSON loading so they reflect the actual course content.

SQL & Databases is Level 2 directly after Mathematics; former levels 2–22 shift by one. Foundation paths use the same Math → SQL → Data Science sequence.

Prompt Engineering owns the general prompting module formerly in Generative AI and system-instruction lessons formerly in LLM Engineering. Moved lesson IDs, quizzes and exercises are preserved. Specialized retrieval, security and deployment material remains in its relevant courses. A dedicated instruction-design and evaluation module supplements the relocated content.

The JSON loader now accepts numeric as well as string durations, preventing valid course modules from being silently skipped.

## Asset-backed content migration

All thirteen newly introduced courses now store their complete modules under
`assets/content/<course>/module_*.json`. Interview Questions modules for all forty
courses are also JSON assets, replacing runtime generation. Prompt Engineering
owns its migrated lessons on disk; they have been removed from the original
Generative AI and LLM Engineering asset files.

`assets/content/courses.json` is the startup registration manifest. New-course
Dart files retain display metadata only. The loader preserves migrated lesson and
quiz IDs, exercises, project links and XP, and fails explicitly if a registered
asset is missing or invalid. See `assets/content/README.md` for editing rules.


## Deterministic Interview Prep

Interview preparation is now a separate experience at `/interview` and
`/interview/<courseId>`, linked from course pages and the skill graph. Each course
owns an `interview.json` asset; the former interview lesson modules have been
removed from the learning catalog. Legacy interview lesson/module URLs redirect
to the course prep screen.

Five modes share static pools: Practice, timed Interview, 20-question Rapid Fire,
Scenario and 10-question Mock Interview. Question formats include concepts,
flashcards, MCQs, multi-select, true/false, code output, debugging, architecture,
ordering and scenarios. Follow-ups are predefined, including the RAG cosine
similarity → chunk-size experiment → generation-quality diagnosis chain.

Objective answers are scored against exact keys. Free text is never graded;
concept coverage is explicitly self-reported before reveal. Results separate the
two metrics, exclude skips from accuracy and flag categories for review. Results
are saved locally; typed text is neither persisted nor sent anywhere. There are
no LLM/API calls, model dependencies or inference costs in this feature.

## Specialist course depth

All 13 courses from PyTorch through Prompt Engineering now have eight learning
modules loaded from their existing asset directories: 30 lessons per specialist
course and 32 for Prompt Engineering. The 78 added modules contain 312 new
lessons, each with a worked example, applied practice and a knowledge check.
Original lesson IDs and labs are preserved. Interview Prep remains separate;
156 additional static scenario/follow-up questions cover the new module topics.
