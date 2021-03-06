# Builds a hierarchical structure for the site, based on the YAML front matter of each page
# Starts from a page called "index.md", and follows "children" links in the YAML front matter
module SiteStructure
  
  ROOT = "index.md"
  
  class Generator < Jekyll::Generator
    def generate(site)
      navgroups = site.pages.detect { |page| page.path == SiteStructure::ROOT }.data['navgroups']
      navgroups.each do |ng|
        ng['page'] = site.pages.detect { |page| page.path == ng['page'] }
      end
      puts navgroups
      site.data['navgroups'] = navgroups
      site.data['structure'] = gen_structure(site, SiteStructure::ROOT, nil, navgroups)
    end
    
    def gen_structure(site, pagename, parent, navgroups)
      page = site.pages.detect { |page| page.path == pagename }
      throw "Could not find a page called: #{pagename} (referenced from #{page ? page.url : nil})" unless page
      
      # My navgroup is (first rule matches):
      # 1. what I have explicitly declared
      # 2. if I find my path referred to in the global navgroup list
      # 3. my parent's navgroup
      unless page.data['navgroup']
        match = navgroups.detect { |ng| ng['page'] == page }
        if match
          page.data['navgroup'] = match['id']
        elsif parent
          page.data['navgroup'] = parent.data['navgroup']
        end
      end
      puts "#{page.path} #{page.data['navgroup']}"
      
      # Figure out second level menu
      # If there's no parent => I'm at the top level, so no action
      # If there's a parent, but parent has no parent => I'm at second level, so set second-level menu
      # Otherwise, use the parent's second level menu
      if parent && !parent.data['parent']
        page.data['menu2parent'] = page
        page.data['menu2'] = page.data['children']
      elsif parent && parent.data['parent']
        page.data['menu2parent'] = parent.data['menu2parent']
        page.data['menu2'] = parent.data['menu2']
      end
      
      page.data['parent'] = parent
      if page.data['children']
        page.data['children'].each do |c|
          c['reference'] = gen_structure(site, c['path'], page, navgroups)
        end
      end
      
      page
    end
  end
end