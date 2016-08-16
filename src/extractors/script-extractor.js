import Extractor from './extractor';


class ScriptExtractor extends Extractor {

  constructor(options) {
    super(options);
  }

}

ScriptExtractor.handle = 'script';
ScriptExtractor.exts = ['.js', '.coffee'];

ScriptExtractor.prototype.openBrick = '\\\\?[\'"]';
// if the url appears inside a string, its quotes will be escaped

export default ScriptExtractor;


