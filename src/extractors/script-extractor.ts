import { ExtractorOptions } from "../options"
import Extractor from "./extractor"

export class ScriptExtractor extends Extractor {

  public static handle = "script"
  public static exts = [".js", ".coffee"]

  constructor(options: ExtractorOptions) {
    super(options)
  }

  // if the url appears inside a string, its quotes will be escaped
  public get openBrick() { return '\\\\?[\'"]' }
}

export default ScriptExtractor
