
async function main() {
  console.log('hi');
}

main().then(() => process.exit(0)).catch((e: Error) => {
  console.error(`Crashed! ${e.message}\n${e.stack}`);
  process.exit(-1);
});