# data/

Machine-readable descriptions of the platform, used by the generated chapters.

- `environments/*.json` — one file per environment, produced by the
  infrastructure pipeline. The expected shape is documented in
  `scripts/platformdata.py` (the `Environment` and `Workspace` classes).

How the files get here is up to the pipeline that produces them: copy them in
with a CI job, fetch them from an artefact store in `before_script`, or commit
them when they change. The site build only reads them.

If the pipeline's JSON has a different shape, change the `load_environments`
function in `scripts/platformdata.py` — that is the one place the shape is
known. The chapters only see the Python objects.
