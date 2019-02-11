module Qo
  class EitherLeftBranch < Branch
    def initialize(destructure: false)
      super(
        name: 'left',
        destructure: destructure,
        precondition:
        extractor: :value,
        default: false
      )
    end
  end
end
