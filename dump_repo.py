from pathlib import Path

output_file = "repo_dump.txt"
with open(output_file, "w", encoding="utf-8") as out:
    for pattern in ("*.dart", "*.gql"):
        for path in Path(".").rglob(pattern):
            if path.is_file() and not any(part.startswith(".") for part in path.parts):
                try:
                    content = path.read_text(encoding="utf-8")
                except:
                    continue
                out.write(f"{path.as_posix()}\n")
                out.write(content)
                out.write("\n\n" + "="*80 + "\n\n")
print("Done:", output_file)