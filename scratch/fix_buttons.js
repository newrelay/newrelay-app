
const fs = require("fs");
const files = [
  "app/javascript/dashboard/components/widgets/conversation/CannedResponsesDropdown.vue",
  "app/javascript/dashboard/components/widgets/WootWriter/ReplyBottomPanel.vue",
  "app/javascript/dashboard/components/widgets/conversation/InboxReplyBottomPanel.vue",
  "app/javascript/dashboard/components-next/Contacts/ContactsCard/ContactsCard.vue",
  "app/javascript/dashboard/components-next/Companies/CompaniesHeader/components/CompanyMoreActions.vue",
  "app/javascript/dashboard/components-next/Companies/CompaniesHeader/components/CompanySortMenu.vue"
];

files.forEach(file => {
  let p = require("path").join(__dirname, "../", file);
  if (!fs.existsSync(p)) return;
  let lines = fs.readFileSync(p, "utf8").split("\n");
  
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].includes(":class=") && lines[i].includes(" border border-border hover:border-transparent")) {
      lines[i] = lines[i].replace(" border border-border hover:border-transparent", "");
    }
  }
  
  fs.writeFileSync(p, lines.join("\n"));
});
console.log("Fixed buttons.");

