import { readFileSync } from 'fs';
import * as path from 'path';

import * as chai from 'chai';
import * as chaiAsPromised from 'chai-as-promised';
import { expect } from 'chai';

import {episodeListToEpisodeURLs, episodePageToContent} from '../src/index';

chai.should();
chai.use(chaiAsPromised);

function delay(ms: number) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

it('makes sure the test suite works', async () => {
  await delay(10);
  expect(1 + 2).to.equal(3);
});

describe('the episodeListToEpisodeURLs method', () => {
  it ('reads the example file', () => {
    const html = readFileSync(path.join(__dirname, 'fixtures', 'episode-list.html'), 'utf8');
    const output = episodeListToEpisodeURLs('https://www.springfieldspringfield.co.uk/episode_scripts.php?tv-show=friends', html);

    expect(output.length).to.be.greaterThan(100);

    const first = output[0];
    expect(first).to.match(/^https:\/\//);
  });
});

describe('the episodePageToContent method', () => {
  it ('reads the example file', () => {
    const html = readFileSync(path.join(__dirname, 'fixtures', 'episode-page.html'), 'utf8');
    const output = episodePageToContent(html);

    console.log(JSON.stringify(output, null, 2));
    expect(output).length.to.be.greaterThan(0);
  });
});