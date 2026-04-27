from pathlib import Path

output_file = "repo_paths.txt"

with open(output_file, "w", encoding="utf-8") as out:
    for pattern in ("*.dart", "*.gql"):
        for path in Path(".").rglob(pattern):
            if path.is_file() and not any(part.startswith(".") for part in path.parts):
                out.write(f"{path.as_posix()}\n")

print("Done:", output_file)
