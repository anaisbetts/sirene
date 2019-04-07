import * as cheerio from 'cheerio';
import * as URL from 'url';

async function main() {
  console.log('hi');
}

export function episodeListToEpisodeURLs(href: string, documentText: string) {
  const $ = cheerio.load(documentText);

  const ret: string[] = [];
  const uri = URL.parse(href);

  $('.season-episodes a').each((_, e) => {
    const relPath = $(e).attr('href');
    ret.push(`${uri.protocol}//${uri.host}/${relPath}`);
  });

  return ret;
}

export function episodePageToContent(documentText: string) {
  const $ = cheerio.load(documentText);
  const html = $('.episode_script .scrolling-script-container').first().html();

  return html!.split(/([\n]|<br>| -|- )/)
    .map(x => cheerio.load(x).root().text())
    .map(x => x.replace(/^\" /, ''))
    .filter(x => x.length > 2 && x != '<br>');
}

if (process.mainModule === module) {
  main().then(() => process.exit(0)).catch((e: Error) => {
    console.error(`Crashed! ${e.message}\n${e.stack}`);
    process.exit(-1);
  });
}