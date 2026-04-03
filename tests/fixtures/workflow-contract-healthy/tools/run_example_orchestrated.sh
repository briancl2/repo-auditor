#!/usr/bin/env bash
python3 tools/build_phase3_working_set.py
python3 tools/init_phase3_curated_sections.py
# edit the canonical curated artifact in place
# replace all TODO markers before recording phase3_curated
