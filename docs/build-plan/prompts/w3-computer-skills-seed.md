# Task
Add a "Computer Skills" subject with a starter roadmap unit of lessons, as seed data.

# Repo
C:\Users\dvdphobia\Desktop\workspaces\RIKSA, Spring Boot + Flyway. Read AGENTS.md first.

# Relevant files
- src/main/resources/db/migration/V28__seed_high_school_learning_curriculum.sql, V29–V31 — the exact seed format for categories, roadmap units, lessons, sections, and QCM exercises (V31 converted text exercises to multiple choice)
- src/main/java/com/riksa/learning/ — entities, to confirm column names
- src/main/java/com/riksa/admin/service/CategoryAdminService.java, LessonAdminService.java — admin rules to respect

# Context
RIKSA is a Grade 12 (Bac II) learning app for Cambodia; English and Khmer. Computer skills is a new, non-exam subject to make the app useful every day. Lessons must be short (3–5 minutes), practical, and bilingual in the same way existing seeds are.

# Do
1. Migration V38 (V35–V37 are taken) seeding category "Computer Skills / ជំនាញកុំព្យូទ័រ" and one roadmap unit "Digital basics" with 5 lessons: keyboard shortcuts that save time; files and folders (organise your study files); searching the web well and spotting fake info; staying safe online (passwords, 2FA, scams on Telegram/Facebook); making a simple slide presentation.
2. Each lesson: 2–3 short sections and 3 QCM exercises, same structure as V28–V31, with sensible baseXp and difficulty EASY.
3. Match every column and enum exactly as existing seeds use them. Use fixed UUIDs so the migration is deterministic.
4. A test (or a documented query) proving the category, unit, lessons and exercises load via the existing lesson endpoints.

# Do NOT
- Do not commit, push, rebase, or switch branches.
- Do not modify files outside src/main/resources/db/migration/V38__*.sql and src/test/java/com/riksa/learning/**.
- Do not edit existing migrations.

# Deliverable
The migration, real `./mvnw test` output, and a list of the lesson titles in both languages for review. Flag any Khmer you are not confident about.

# Risks
End with a "## Risks" section.
