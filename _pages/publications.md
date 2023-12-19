---
layout: page
permalink: /publications/
title: Publications
description:
nav: true
nav_order: 1
---


<b> Google scholar stats </b>
* Citations: {{ site.data.scholar.citations }}
* h-index: {{ site.data.scholar.h_index }}
* i10-index: {{ site.data.scholar.i10_index }}


<!-- _pages/publications.md -->
<div class="publications">

{% bibliography -f {{ site.scholar.bibliography }} %}

</div>
