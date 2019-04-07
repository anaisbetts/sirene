module.exports = function(wallaby) {
  return {
    files: [
      'src/**/*.ts'
    ],
    tests: [
      'test/**/*.ts',
      'test/**/*.html'
    ],
    env: {
      type: 'node'
    }
  }
}