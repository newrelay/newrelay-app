
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

    // Rule: Section Headings (like h1, h2) unless it is an EmptyState heading
    // To be safe, we will just target h1 for now since section headers are usually h1
    // We replace things like text-lg, text-xl, text-2xl, font-bold, font-semibold
    const h1Regex = /(<h1[^>]*?class=["'])([^"']*?)(["'])/g;
    content = content.replace(h1Regex, (match, p1, p2, p3) => {
      let newClasses = p2
        .replace(/\btext-(lg|xl|2xl|3xl|4xl)\b/g, "text-[16px]")
        .replace(/\btext-base\b/g, "text-[16px]")
        .replace(/\bfont-(semibold|bold|extrabold)\b/g, "font-[500]")
        .replace(/\bfont-medium\b/g, "font-[500]");
      
      // If text-[16px] or font-[500] is not there after replacement but there was some text size or font weight
      if (!newClasses.includes("text-[16px]")) newClasses += " text-[16px]";
      if (!newClasses.includes("font-[500]")) newClasses += " font-[500]";
      
      // cleanup spaces
      newClasses = newClasses.replace(/\s+/g, " ").trim();
      
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

console.log(`Modified ${modifiedFiles} files with heading classes.`);

