module.exports = function(wallaby) {
  return {
    files: [
      'src/**/*.ts'
    ],
    tests: [
      'test/**/*.ts'
    ],
    env: {
      type: 'node'
    }
  }
}