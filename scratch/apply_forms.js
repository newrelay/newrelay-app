
const fs = require("fs");
const path = require("path");

function walkSync(dir, filelist = []) {
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
  path.join(__dirname, "../app/javascript/dashboard/components-next"),
  path.join(__dirname, "../app/javascript/dashboard/routes/dashboard")
];

let modifiedFiles = 0;

targetDirs.forEach(dir => {
  if (!fs.existsSync(dir)) return;
  const files = walkSync(dir);
  files.forEach(file => {
    let content = fs.readFileSync(file, "utf8");
    let changed = false;

    // 1. Labels
    const labelRegex = /(<label[^>]*?class=["'])([^"']*?)(["'])/g;
    content = content.replace(labelRegex, (match, p1, p2, p3) => {
      // replace any text sizing or font weight with strict rules
      let newClasses = p2
        .replace(/\btext-(xs|sm|base|lg|xl)\b/g, "")
        .replace(/\bfont-(normal|medium|semibold|bold)\b/g, "");
      
      if (!newClasses.includes("text-[13.5px]")) newClasses += " text-[13.5px]";
      if (!newClasses.includes("font-[500]")) newClasses += " font-[500]";
      if (!newClasses.includes("text-foreground")) newClasses += " text-foreground";
      
      newClasses = newClasses.replace(/\s+/g, " ").trim();
      
      if (newClasses !== p2.replace(/\s+/g, " ").trim()) {
        changed = true;
        return `${p1}${newClasses}${p3}`;
      }
      return match;
    });

    // 2. Inputs/Textareas (excluding type="checkbox" or "radio" or "hidden")
    const inputRegex = /(<(?:input|textarea)[^>]*?class=["'])([^"']*?)(["'])/g;
    content = content.replace(inputRegex, (match, p1, p2, p3) => {
      // skip checkboxes/radios if they are explicitly mentioned before the class attribute
      if (match.includes("type=\"checkbox\"") || match.includes("type=\"radio\"")) return match;
      
      let newClasses = p2
        .replace(/\btext-(xs|sm|base|lg)\b/g, "")
        .replace(/\bshadow-(sm|md)\b/g, "")
        .replace(/\brounded-(sm|md|lg)\b/g, "");
        
      if (!newClasses.includes("text-[14px]")) newClasses += " text-[14px]";
      if (!newClasses.includes("shadow-sm")) newClasses += " shadow-sm";
      if (!newClasses.includes("rounded-md")) newClasses += " rounded-md";
      if (!newClasses.includes("border-border/80")) newClasses += " border-border/80";
      if (!newClasses.includes("bg-background")) newClasses += " bg-background";
      if (!newClasses.includes("focus-visible:ring-1")) newClasses += " focus-visible:ring-1";
      if (!newClasses.includes("focus-visible:ring-primary/30")) newClasses += " focus-visible:ring-primary/30";
      
      newClasses = newClasses.replace(/\s+/g, " ").trim();
      
      if (newClasses !== p2.replace(/\s+/g, " ").trim()) {
        changed = true;
        return `${p1}${newClasses}${p3}`;
      }
      return match;
    });

    if (changed) {
      fs.writeFileSync(file, content);
      modifiedFiles++;
    }
  });
});

console.log(`Modified ${modifiedFiles} files with form classes.`);

