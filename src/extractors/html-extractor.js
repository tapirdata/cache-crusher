import Extractor from './extractor';


class HtmlExtractor extends Extractor {
  
  constructor(options) {
    super(options);
  }

}

HtmlExtractor.handle = 'html';
HtmlExtractor.exts = ['.html', '.xml', '.jade'];

HtmlExtractor.prototype.preBrick = '(?:src|href)\\s*=\\s*';


export default HtmlExtractor;


