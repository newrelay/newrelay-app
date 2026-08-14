
const fs = require("fs");
const path = require("path");

function walkSync(dir, filelist = []) {
  if (!fs.existsSync(dir)) return filelist;
  fs.readdirSync(dir).forEach(file => {
    const dirFile = path.join(dir, file);
    if (fs.statSync(dirFile).isDirectory()) {
      filelist = walkSync(dirFile, filelist);
    } else if (dirFile.endsWith(".vue")) {
      filelist.push(dirFile);
    }
  });
  return filelist;
}

const targetDirs = [
  path.join(__dirname, "../app/javascript/dashboard/components"),
  path.join(__dirname, "../app/javascript/shared/components"),
  path.join(__dirname, "../app/javascript/dashboard/routes")
];

let files = [];
targetDirs.forEach(dir => {
  files = files.concat(walkSync(dir));
});
// Deduplicate files in case of overlap
files = [...new Set(files)];

let modHeadings = 0;
let modButtons = 0;
let modForms = 0;
let modColors = 0;

files.forEach(file => {
  let content = fs.readFileSync(file, "utf8");
  let originalContent = content;

  // 1. Headings
  const h1Regex = /(<h1[^>]*?class=["'])([^"']*?)(["'])/g;
  content = content.replace(h1Regex, (match, p1, p2, p3) => {
    let newClasses = p2
      .replace(/\btext-(lg|xl|2xl|3xl|4xl)\b/g, "text-[16px]")
      .replace(/\btext-base\b/g, "text-[16px]")
      .replace(/\bfont-(semibold|bold|extrabold)\b/g, "font-[500]")
      .replace(/\bfont-medium\b/g, "font-[500]");
    if (!newClasses.includes("text-[16px]")) newClasses += " text-[16px]";
    if (!newClasses.includes("font-[500]")) newClasses += " font-[500]";
    newClasses = newClasses.replace(/\s+/g, " ").trim();
    return `${p1}${newClasses}${p3}`;
  });
  if (content !== originalContent) modHeadings++;
  let tempContent1 = content;

  // 2. Buttons
  const btnRegex = /(<(?:RelayButton|woot-button|Button)\b[^>]*?variant=["'](?:ghost|transparent)["'][^>]*?class=["'])([^"']*?)(["'])/gs;
  content = content.replace(btnRegex, (match, p1, p2, p3) => {
    if (!p2.includes("border border-border") && !p2.includes("hover:border-transparent")) {
      return `${p1}${p2} border border-border hover:border-transparent${p3}`;
    }
    return match;
  });
  const btnRegexNoClass = /(<(?:RelayButton|woot-button|Button)\b[^>]*?variant=["'](?:ghost|transparent)["'][^>]*?)(\/?>)/gs;
  content = content.replace(btnRegexNoClass, (match, p1, p2) => {
    if (p1.includes("class=")) return match;
    return `${p1} class="border border-border hover:border-transparent" ${p2}`;
  });
  if (content !== tempContent1) modButtons++;
  let tempContent2 = content;

  // 3. Forms
  const labelRegex = /(<label[^>]*?class=["'])([^"']*?)(["'])/g;
  content = content.replace(labelRegex, (match, p1, p2, p3) => {
    let newClasses = p2.replace(/\btext-(xs|sm|base|lg|xl)\b/g, "").replace(/\bfont-(normal|medium|semibold|bold)\b/g, "");
    if (!newClasses.includes("text-[13.5px]")) newClasses += " text-[13.5px]";
    if (!newClasses.includes("font-[500]")) newClasses += " font-[500]";
    if (!newClasses.includes("text-foreground")) newClasses += " text-foreground";
    newClasses = newClasses.replace(/\s+/g, " ").trim();
    return `${p1}${newClasses}${p3}`;
  });
  const inputRegex = /(<(?:input|textarea)[^>]*?class=["'])([^"']*?)(["'])/g;
  content = content.replace(inputRegex, (match, p1, p2, p3) => {
    if (match.includes("type=\"checkbox\"") || match.includes("type=\"radio\"")) return match;
    let newClasses = p2.replace(/\btext-(xs|sm|base|lg)\b/g, "").replace(/\bshadow-(sm|md)\b/g, "").replace(/\brounded-(sm|md|lg)\b/g, "");
    if (!newClasses.includes("text-[14px]")) newClasses += " text-[14px]";
    if (!newClasses.includes("shadow-sm")) newClasses += " shadow-sm";
    if (!newClasses.includes("rounded-md")) newClasses += " rounded-md";
    if (!newClasses.includes("border-border/80")) newClasses += " border-border/80";
    if (!newClasses.includes("bg-background")) newClasses += " bg-background";
    if (!newClasses.includes("focus-visible:ring-1")) newClasses += " focus-visible:ring-1";
    if (!newClasses.includes("focus-visible:ring-primary/30")) newClasses += " focus-visible:ring-primary/30";
    newClasses = newClasses.replace(/\s+/g, " ").trim();
    return `${p1}${newClasses}${p3}`;
  });
  if (content !== tempContent2) modForms++;
  let tempContent3 = content;

  // 4. Colors
  const classRegex = /(class=["'])([^"']*?)(["'])/g;
  content = content.replace(classRegex, (match, p1, p2, p3) => {
    let newClasses = p2
      .replace(/\btext-(gray|slate|zinc|neutral|stone)-[456]00\b/g, "text-muted-foreground")
      .replace(/\btext-(gray|slate|zinc|neutral|stone)-[789]00\b/g, "text-foreground")
      .replace(/\bbg-(gray|slate|zinc|neutral|stone)-[12]00\b/g, "bg-muted")
      .replace(/\bbg-(gray|slate|zinc|neutral|stone)-50\b/g, "bg-background")
      .replace(/\bborder-(gray|slate|zinc|neutral|stone)-[23]00\b/g, "border-border")
      .replace(/\btext-(blue|indigo|purple)-[56]00\b/g, "text-primary")
      .replace(/\bbg-(blue|indigo|purple)-[56]00\b/g, "bg-primary")
      .replace(/\bbg-(blue|indigo|purple)-[5]0\b/g, "bg-primary/10")
      .replace(/\btext-(red|rose)-[56]00\b/g, "text-destructive")
      .replace(/\bbg-(red|rose)-[56]00\b/g, "bg-destructive")
      .replace(/\btext-\[#[0-9a-fA-F]{3,6}\]\b/g, "text-muted-foreground")
      .replace(/\bbg-\[#[0-9a-fA-F]{3,6}\]\b/g, "bg-muted");
    return `${p1}${newClasses}${p3}`;
  });
  if (content !== tempContent3) modColors++;

  if (content !== originalContent) {
    fs.writeFileSync(file, content);
  }
});

console.log(`Legacy sweep complete.`);
console.log(`Headings modified in ${modHeadings} files.`);
console.log(`Buttons modified in ${modButtons} files.`);
console.log(`Forms modified in ${modForms} files.`);
console.log(`Colors modified in ${modColors} files.`);

