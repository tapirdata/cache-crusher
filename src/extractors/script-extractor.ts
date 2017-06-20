import Extractor from "./extractor"
import { ExtractorOptions } from "./extractor"

export class ScriptExtractor extends Extractor {

  constructor(options: ExtractorOptions) {
    super(options)
  }

}

(ScriptExtractor as any).handle = "script";
(ScriptExtractor as any).exts = [".js", ".coffee"];

(ScriptExtractor.prototype as any).openBrick = '\\\\?[\'"]'
// if the url appears inside a string, its quotes will be escaped

export default ScriptExtractor
