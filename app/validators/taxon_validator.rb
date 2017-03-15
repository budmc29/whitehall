class TaxonValidator < ActiveModel::Validator
  def validate(edition)
    if missing_taxons?(edition)
      edition.errors.add(:base, "You need to the document to one or more topics in the new taxonomy before publishing.")
    end
  end

private

  def missing_taxons?(edition)
    Whitehall.tagging_taxonomy_enabled? && edition.can_be_tagged_to_taxonomy? && edition.expanded_links.taxons.empty?
  end
end
