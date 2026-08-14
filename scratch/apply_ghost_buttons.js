
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

    // Match Button or RelayButton with variant="ghost" or variant="transparent"
    // and inject the class border border-border hover:border-transparent if not present
    // This is a naive regex but good enough for typical Vue templates
    const regex = /(<(?:Relay)?Button\b[^>]*?variant=["'](?:ghost|transparent)["'][^>]*?class=["'])([^"']*?)(["'])/gs;
    
    content = content.replace(regex, (match, p1, p2, p3) => {
      if (!p2.includes("border border-border") && !p2.includes("hover:border-transparent")) {
        changed = true;
        return `${p1}${p2} border border-border hover:border-transparent${p3}`;
      }
      return match;
    });
    
    // Catch cases where there is no class attribute yet
    const regexNoClass = /(<(?:Relay)?Button\b[^>]*?variant=["'](?:ghost|transparent)["'][^>]*?)(\/?>)/gs;
    content = content.replace(regexNoClass, (match, p1, p2) => {
      // If it already has a class attribute, skip
      if (p1.includes("class=")) return match;
      changed = true;
      return `${p1} class="border border-border hover:border-transparent" ${p2}`;
    });

    if (changed) {
      fs.writeFileSync(file, content);
      modifiedFiles++;
    }
  });
});

console.log(`Modified ${modifiedFiles} files with ghost button classes.`);

