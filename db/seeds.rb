$doc_root = File.join(File.expand_path(File.join('..', '..'), __FILE__), 'doc')

def doc(*path)
  File.read(File.join($doc_root, *path))
end

version = Documentation::Version.create(ordinal: '0.0.0')

guide = version.pages.create(:title => "Developers' Guide", :content => doc('developers-guide', 'overview.md'))
guide.children.create(:title => 'Authorization', :content => doc('developers-guide', 'authorization.md'))
guide.children.create(:title => 'Search Backends', :content => doc('developers-guide', 'search-backends.md'))
guide.children.create(:title => 'Customization', :content => doc('developers-guide', 'customization.md'))
views = guide.children.create(:title => 'Building your own views', :content => doc('developers-guide', 'building-views', 'overview.md'))
views.children.create(:title => 'Accessing Pages', :content => doc('developers-guide', 'building-views', 'accessing-pages.md'))
views.children.create(:title => 'Helpers', :content => doc('developers-guide', 'building-views', 'helpers.md'))

version.pages.create(:title => "Using Markdown", :content => doc('markdown', 'overview.md'))
