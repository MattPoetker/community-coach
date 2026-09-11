/**
 * Plain text in, ProseMirror document out.
 *
 * Bodies are stored as a constrained document rather than HTML, so the composer sends a
 * document too. When a real editor replaces the textarea it will produce this shape
 * directly and this function goes away — until then, blank-line-separated paragraphs are
 * the honest conversion.
 */
export type Doc = { type: string; content?: Doc[]; text?: string; marks?: unknown[] };

export function toDocument(text: string): Doc {
  const paragraphs = text
    .split(/\n{2,}/)
    .map((chunk) => chunk.trim())
    .filter(Boolean);

  return {
    type: "doc",
    content:
      paragraphs.length > 0
        ? paragraphs.map((paragraph) => ({
            type: "paragraph",
            content: [{ type: "text", text: paragraph }],
          }))
        : [{ type: "paragraph" }],
  };
}

/** Renders a stored document back to paragraphs of plain text. */
export function toParagraphs(doc: unknown): string[] {
  const node = doc as Doc | null;
  if (!node?.content) return [];

  return node.content
    .map((child) => flatten(child))
    .map((line) => line.trim())
    .filter(Boolean);
}

function flatten(node: Doc): string {
  if (node.type === "text") return node.text ?? "";
  if (node.type === "hardBreak") return "\n";
  return (node.content ?? []).map(flatten).join("");
}
