
const fs = require("fs");
const files = [
  "app/javascript/dashboard/components/widgets/VideoCallButton.vue",
  "app/javascript/dashboard/components/widgets/conversation/InboxReplyBottomPanel.vue",
  "app/javascript/dashboard/components/widgets/WootWriter/ReplyBottomPanel.vue"
];

files.forEach(file => {
  let p = require("path").join(__dirname, "../", file);
  if (!fs.existsSync(p)) return;
  let content = fs.readFileSync(p, "utf8");
  
  // Replace the corrupted string
  content = content.replace(/ border border-border hover:border-transparent'/g, "'");
  
  fs.writeFileSync(p, content);
});
console.log("Fixed buttons part 2.");

