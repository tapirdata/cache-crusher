class Extractor {

  constructor(options = {}) {
    this.urlBase = options.urlBase || '';
    if (options.partBrick) {
      this.partBrick = options.partBrick;
    }
    this.pathBrick = `${this.urlBase}(?:${this.partBrick}/)*${this.partBrick}`;
  }

  getBrick() {
    let brickParts = [
      '(', this.preBrick, ')',
      '(', this.openBrick, ')',
      '(', this.pathBrick, ')',
      '(', this.queryBrick, ')',
      '(', this.closeBrick, ')',
      '(', this.postBrick, ')'
    ];
    return brickParts.join('');
  }

  createPattern() {
    return new RegExp(this.getBrick());
  }

  getPattern() {
    let pattern = this._pattern;
    if (pattern == null) {
      pattern = this.createPattern();
      this._pattern = pattern;
    }
    return pattern;
  }

  split(match) {
    let preambleCut = 1 + this.preambleBrickNum;
    let pathCut = preambleCut + this.pathBrickNum;
    let queryCut = pathCut + this.queryBrickNum;
    return {
      preamble: match.slice(1, preambleCut).join(''),
      path: match.slice(preambleCut, pathCut).join(''),
      query: match.slice(pathCut, queryCut).join(''),
      postamble: match.slice(queryCut).join('')
    };
  }
}

Extractor.handle = 'base';

Object.assign(Extractor.prototype, {
  preambleBrickNum: 2,
  pathBrickNum: 1,
  queryBrickNum: 1,

  partBrick: '[^\/#?\'"]+',
  preBrick: '',
  postBrick: '',
  openBrick: '[\'"]',
  closeBrick: '\\2',
  queryBrick: '(?:\\?[^#"\']*)?',
});  


export default Extractor;


