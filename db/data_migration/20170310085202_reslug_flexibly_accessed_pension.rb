old_slug = "flexibly-accessed-pension-payment-repayment-claim-tax-year-2015-2016-p55" 
new_slug = "flexibly-accessed-pension-payment-repayment-claim-tax-year-p55"

changeling = Document.find_by(slug: old_slug)
if changeling
  puts "Changing document slug #{old_slug} -> #{new_slug}"
  changeling.update_attribute(:slug, new_slug)
  router.add_redirect_route("/government/publications/#{old_slug}",
                            'exact',
                            "/government/publications/#{new_slug}")
else
  puts "Can't find document with slug of #{old_slug}"
end