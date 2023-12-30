---
title: "How to Set Up a Blog with Hugo"
date: 2023-12-19T11:44:01Z
slug: 2023-12-19-how-to-set-up-a-blog-with-hugo
type: posts
draft: false
categories:
  - Information
tags:
  - Hugo
  - Blogging
---
For passionate side project enthusiasts, documenting and sharing your projects can be a challenging task. Often, projects become a tangled mess with undocumented code, forgotten execution procedures, and hidden gems of experience buried in a labyrinthine GitHub repository. This isn't an ideal scenario for showcasing your hard work and lessons learned.
## Why Choose a Custom Blog Setup?
While there are popular blogging platforms like Medium, Blogger, or Wordpress, opting for a custom setup provides total control and a valuable learning experience. In this quest, I turned to [Hugo](https://gohugo.io/), an incredibly fast static site generator implemented in GoLang. Hugo uses the versatile and dynamic syntax of `html/template` and `text/template` libraries.
![Hugo Logo](https://raw.githubusercontent.com/gohugoio/gohugoioTheme/master/static/images/hugo-logo-wide.svg?sanitize%253Dtrue)
## Getting Started with Hugo
The beauty of Hugo lies in its flexibility. Take, for example, this code snippet that enumerates all pages. When the page title is "Posts," it generates a list of links to all posts. This simplicity is just the tip of the iceberg, as Hugo's Go template syntax allows for much more complex filtering.
```html
<ul>
	{{ range .Paginator.Pages }}
	  <li>
		  <div class="post-title">
			  {{ if eq $listtitle "Posts" }}
			    {{ .Date.Format "2006-01-02" }} <a href="{{ .RelPermalink }}">{{.Title }}</a>
			  {{ else }}
				  <a href="{{ .RelPermalink }}">{{.Title }}</a>
			  {{ end }}
		  </div>
	  </li>
	{{ end }}
</ul>
```
## Markdown Magic and Theming
With Hugo, normal posts are written in Markdown, and the platform supports numerous extensions either natively or through manual integration using JavaScript. Theming support allows you to choose from a variety of themes available at Hugo Themes, making it easy to build a developer blog, documentation website, portfolio, and more.
## Deploying with GitHub Actions
GitHub simplifies the deployment of Hugo websites through GitHub Actions. With just one click, deploying becomes a breeze—add a preconfigured workflow, and you’re done! This seamless integration enhances the accessibility and visibility of your blog, ensuring that your projects get the attention they deserve.
![hugo actions](/images/hugo_actions.jpeg)
In conclusion, setting up a blog with Hugo provides not only control and customization but also an opportunity to delve into the intricacies of static site generation. Document your projects, share your experiences, and let Hugo empower your blogging journey.
