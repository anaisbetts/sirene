import * as cheerio from 'cheerio';
import * as URL from 'url';
import axios from 'axios';

import * as yargs from 'yargs';
import { readFileSync } from 'fs';
import { asyncMap } from './promise-array';

async function main() {
  const args: any = yargs.argv;

  const shows = readFileSync(args.showList, 'utf8').split('\n').filter(x => x.length > 2);
  //console.log(shows);
  console.log(JSON.stringify(await collectDataFromShowList(shows), null, 2));
}

export async function collectDataFromShowList(shows: string[]) {
  const episodeUrls = await asyncMap(shows, async uri => {
    const html: string = (await axios.get(uri)).data;
    return episodeListToEpisodeURLs(uri, html);
  });

  const justUrls = Array.from(episodeUrls.values()).reduce((acc, x) => acc.concat(x), []);

  const ret = await asyncMap(justUrls, async (x) => {
    return episodePageToContent((await axios.get(x)).data);
  });

  return Array.from(ret.values());
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