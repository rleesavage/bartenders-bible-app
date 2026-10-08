BARTENDER'S BIBLE APP — PHASE 2
================================

WHAT THIS PHASE DOES

This is the first full mobile shell wired to the live v1.0 API.

SERVER PATCH — upload ONLY:
  api/v1/search.php

That replacement extends the existing Search endpoint with:
- ordinary Full Bar search
- voice phrase ingredient detection
- Create a Drink Suggestion scoring
- alcohol / mixer / occasion vocabulary for the app

NO SQL CHANGES.

MOBILE SOURCE
-------------
The complete Flutter source is under:
  mobile/

Current screens:
- Login
- Create Account
- Home
- Drinks
- Drink Detail
- Encyclopedia
- My Notebook
- Search Drinks
- About

APP TERMINOLOGY
---------------
- Bar Talk
- Bar Notes
- My Notebook

HOME
----
Shows the live featured drink returned by home.php.

DRINKS
------
Loads all 500 live drinks, includes a quick local filter, thumbnails,
descriptions, and opens Drink Detail.

DRINK DETAIL
------------
Shows:
- hero image
- description / pronunciation when present
- recipes and ingredients
- instructions
- glassware / garnish / technique / ice
- recipe service / ice / garnish / glassware notes
- Food Pairings
- Bar Talk
- Bar Notes
- the logged-in user's My Notebook entries for that drink
- Add Note for This Drink, saved into the same personal_notebook used by
  the My Notebook screen

ENCYCLOPEDIA
------------
Searchable list plus full-entry modal.

MY NOTEBOOK
-----------
Search, add note/recipe, expand entries, and delete entries.
All operations are scoped server-side to the authenticated user.

SEARCH / VOICE SEARCH
---------------------
Search the Full Bar:
- typed drink name
- microphone voice phrase

Create a Drink Suggestion:
- up to 4 alcohol selections
- up to 3 mixers/supporting ingredients
- occasion
- returns the top 3 scored established recipes
- voice phrase can also feed the suggestion engine

Example:
  "I have tequila, triple sec and lime"

FOOTER
------
The current main page is omitted from its own navigation.
Drink Detail shows all section links.
Footer ends with:
  Webolium
  Bartenders Bible v1.0
  © RL Savage 2026

BUILD
-----
Flutter SDK was not available in the environment that created this package,
so I have NOT claimed a compiled Flutter build yet.

Use mobile/PLATFORM_SETUP.txt, or commit the package to GitHub and use:
  .github/workflows/android-debug.yml

The workflow generates the Android platform folder, inserts Internet /
microphone / speech-recognition declarations, runs flutter analyze, builds
a debug APK, and uploads the APK as a GitHub Actions artifact.

IMPORTANT SECURITY CLEANUP
--------------------------
The temporary api-test.php used during API testing should be deleted from
the server when testing is finished. The bearer token visible in the earlier
test screenshots should also be revoked/expired rather than used by the app.
The real app will create a fresh token at login.
