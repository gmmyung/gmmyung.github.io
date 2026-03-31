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
I wanted a place to write down project notes without depending on Medium, Notion, or some other hosted platform. Most of my side projects already live on GitHub, so a simple static site felt like the right fit.

## Why Hugo
[Hugo](https://gohugo.io/) is fast, simple, and close to the metal. It is written in Go and uses the standard `html/template` and `text/template` packages, so the whole system is straightforward once you look at a couple of templates.

## A small example
Here is a simple template that lists pages. If the page title is `Posts`, it shows the date next to each entry:
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

That is already enough to build a usable blog, and Hugo still leaves room for more involved filtering when you need it.

## Markdown and themes
Posts are just Markdown files, which is exactly what I wanted. Hugo also has a large theme ecosystem, so getting from "empty repo" to "good enough personal site" is pretty quick.

## Deploying with GitHub Actions
Deployment is also easy. GitHub Pages and GitHub Actions work well with Hugo, and there are starter workflows that cover most of the setup.

If you want full control over the generated site without building your own CMS, Hugo is a solid option.
