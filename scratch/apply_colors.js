
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

    // We will replace tailwind utility colors with semantic colors in class attributes.
    // e.g. text-gray-500 -> text-muted-foreground
    // bg-blue-500 -> bg-primary
    
    const classRegex = /(class=["'])([^"']*?)(["'])/g;
    content = content.replace(classRegex, (match, p1, p2, p3) => {
      let newClasses = p2
        // Grays
        .replace(/\btext-(gray|slate|zinc|neutral|stone)-[456]00\b/g, "text-muted-foreground")
        .replace(/\btext-(gray|slate|zinc|neutral|stone)-[789]00\b/g, "text-foreground")
        .replace(/\bbg-(gray|slate|zinc|neutral|stone)-[12]00\b/g, "bg-muted")
        .replace(/\bbg-(gray|slate|zinc|neutral|stone)-50\b/g, "bg-background")
        .replace(/\bborder-(gray|slate|zinc|neutral|stone)-[23]00\b/g, "border-border")
        
        // Primary (Blues/Indigos)
        .replace(/\btext-(blue|indigo|purple)-[56]00\b/g, "text-primary")
        .replace(/\bbg-(blue|indigo|purple)-[56]00\b/g, "bg-primary")
        .replace(/\bbg-(blue|indigo|purple)-[5]0\b/g, "bg-primary/10")
        
        // Destructive (Reds)
        .replace(/\btext-(red|rose)-[56]00\b/g, "text-destructive")
        .replace(/\bbg-(red|rose)-[56]00\b/g, "bg-destructive")
        
        // Arbitrary hex colors (naive approach, replacing standard hex strings with semantic)
        // Only if they are text-[#...] or bg-[#...]
        .replace(/\btext-\[#[0-9a-fA-F]{3,6}\]\b/g, "text-muted-foreground")
        .replace(/\bbg-\[#[0-9a-fA-F]{3,6}\]\b/g, "bg-muted");

      if (newClasses !== p2) {
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

console.log(`Modified ${modifiedFiles} files with semantic color mappings.`);

