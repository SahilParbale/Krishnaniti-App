const fs = require('fs');
const content = fs.readFileSync('Nagarsevak-Managment/src/pages/tasks/Tasks.tsx', 'utf8');
const lines = content.split('\n');
lines.forEach((l, idx) => {
  if (l.includes('task.') || l.includes('t.')) {
    if (idx > 300 && idx < 600) {
      console.log(`L${idx+1}: ${l.trim()}`);
    }
  }
});
