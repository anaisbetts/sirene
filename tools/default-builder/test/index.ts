import * as chai from 'chai';
import * as chaiAsPromised from 'chai-as-promised';
import { expect } from 'chai';

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