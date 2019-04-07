import { Observable } from 'rxjs';

export function asyncMap<T, TRet>(
  array: T[],
  selector: ((x: T) => Promise<TRet>),
  maxConcurrency = 8): Promise<Map<T, TRet>> {

  return Observable.from(array)
    .map((k) =>
      Observable.defer(() =>
        Observable.fromPromise(selector(k))
          .map((v) => ({ k, v }))))
    .mergeAll(maxConcurrency)
    .reduce((acc, kvp) => {
      acc.set(kvp.k, kvp.v);
      return acc;
    }, new Map())
    .toPromise();
}

export async function asyncReduce<T, TAcc>(
  array: T[],
  selector: ((acc: TAcc, x: T) => Promise<TAcc>),
  seed: TAcc) {
  let acc = seed;
  for (let x of array) {
    acc = await selector(acc, x);
  }

  return acc;
}

export function delay(ms: number) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

export function retryPromise(func: (() => Promise<any>), count = 3) {
  return Observable.defer(() =>
    Observable.fromPromise(func()))
    .retry(count)
    .toPromise();
}