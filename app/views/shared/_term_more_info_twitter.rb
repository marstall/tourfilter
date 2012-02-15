		<div style='float:left'>
		<div class='more_info_body_alternating_2 more_info_body '>
	    <div class='bing_header_alternating_<%=(i)%2+1%>'>
		bing web search results
			<a href='http://www.bing.com/search?q=<%=term_text%>'>more</a>
		</div>
	<div class='underline more_info_body_alternating_2 more_info_body'>
		<%tweets = Tweet.find_by_term_text(term_text,:order=>'id desc')%>
		<%tweets.each_with_index{|tweet,k|%>
		<%
			tweet = result['Title']
			title.gsub! /[-|].+?$/,''
			description = result['Description'][0..50] rescue ''
			url = result['Url']
			uri = URI.parse(url)
	        domain=uri.host
		%>
		<div class='more_info_list_result_item more_info_body_alternating_<%=(j+1)%2+1%>'>
		<a href="<%=url%>"><%=title.strip%></a>
		<span class='gray smaller'><%="&nbsp;[#{domain}]" if domain%></span>
		&nbsp;<%=description%> ...<br>
		</div>
		<%}%>
