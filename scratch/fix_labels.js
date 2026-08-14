
const fs = require("fs");
const files = [
  "app/javascript/dashboard/components-next/relay/label/Label.vue",
  "app/javascript/dashboard/routes/dashboard/conversation/contact/ContactForm.vue",
  "app/javascript/dashboard/components/app/AddAccountModal.vue",
  "app/javascript/dashboard/components/widgets/conversation/EmailTranscriptModal.vue"
];

files.forEach(file => {
  let p = require("path").join(__dirname, "../", file);
  if (!fs.existsSync(p)) return;
  let content = fs.readFileSync(p, "utf8");
  
  // Replace the corrupted string
  content = content.replace(/ text-\[13\.5px\] font-\[500\] text-foreground/g, "");
  
  fs.writeFileSync(p, content);
});
console.log("Fixed labels.");

