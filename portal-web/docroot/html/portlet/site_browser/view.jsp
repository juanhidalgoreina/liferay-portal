<%--
/**
 * Copyright (c) 2000-2012 Liferay, Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or modify it under
 * the terms of the GNU Lesser General Public License as published by the Free
 * Software Foundation; either version 2.1 of the License, or (at your option)
 * any later version.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
 * details.
 */
--%>

<%@ include file="/html/portlet/site_browser/init.jsp" %>

<%
long groupId = ParamUtil.getLong(request, "groupId");
long[] selectedGroupIds = StringUtil.split(ParamUtil.getString(request, "selectedGroupIds"), 0L);
String type = ParamUtil.getString(request, "type", "manageableSites");
String filter = ParamUtil.getString(request, "filter");
boolean includeCompany = ParamUtil.getBoolean(request, "includeCompany");
boolean includeUserPersonalSite = ParamUtil.getBoolean(request, "includeUserPersonalSite");
String callback = ParamUtil.getString(request, "callback");
String target = ParamUtil.getString(request, "target");

PortletURL portletURL = renderResponse.createRenderURL();

portletURL.setParameter("struts_action", "/site_browser/view");
portletURL.setParameter("type", type);
portletURL.setParameter("groupId", String.valueOf(groupId));
portletURL.setParameter("filter", filter);
portletURL.setParameter("includeCompany", String.valueOf(includeCompany));
portletURL.setParameter("includeUserPersonalSite", String.valueOf(includeUserPersonalSite));
portletURL.setParameter("callback", callback);
portletURL.setParameter("target", target);
%>

<aui:form action="<%= portletURL.toString() %>" method="post" name="fm">
	<liferay-ui:search-container
		searchContainer="<%= new GroupSearch(renderRequest, portletURL) %>"
	>
		<c:if test='<%= !type.equals("parentSites") %>'>
			<liferay-ui:search-form
				page="/html/portlet/users_admin/group_search.jsp"
			/>
		</c:if>

		<%
		GroupSearchTerms searchTerms = (GroupSearchTerms)searchContainer.getSearchTerms();

		LinkedHashMap<String, Object> groupParams = new LinkedHashMap<String, Object>();
		%>

		<liferay-ui:search-container-results>

			<%
			results.clear();

			int additionalSites = 0;

			if (includeCompany) {
				if (searchContainer.getStart() == 0) {
					results.add(company.getGroup());
				}

				additionalSites++;
			}

			if (includeUserPersonalSite) {
				if (searchContainer.getStart() == 0) {
					Group userPersonalSite = GroupLocalServiceUtil.getGroup(company.getCompanyId(), GroupConstants.USER_PERSONAL_SITE);

					results.add(userPersonalSite);
				}

				additionalSites++;
			}

			if (filterManageableGroups) {
				groupParams.put("usersGroups", user.getUserId());
			}

			groupParams.put("site", Boolean.TRUE);

			int start = searchContainer.getStart();

			if (searchContainer.getStart() > additionalSites) {
				start = searchContainer.getStart() - additionalSites;
			}

			int end = searchContainer.getEnd() - additionalSites;

			List<Group> groups = null;

			if (type.equals("parentSites")) {
				Group group = GroupLocalServiceUtil.getGroup(groupId);

				groups = group.getAncestors();

				if (Validator.isNotNull(filter)) {
					groups = _filterGroups(groups, filter);
				}

				total = groups.size();
			}
			else if (searchTerms.isAdvancedSearch()) {
				groups = GroupLocalServiceUtil.search(company.getCompanyId(), null, searchTerms.getName(), searchTerms.getDescription(), groupParams, searchTerms.isAndOperator(), start, end, searchContainer.getOrderByComparator());
				total = GroupLocalServiceUtil.searchCount(company.getCompanyId(), null, searchTerms.getName(), searchTerms.getDescription(), groupParams, searchTerms.isAndOperator());
			}
			else {
				groups = GroupLocalServiceUtil.search(company.getCompanyId(), null, searchTerms.getKeywords(), groupParams, start, end, searchContainer.getOrderByComparator());
				total = GroupLocalServiceUtil.searchCount(company.getCompanyId(), null, searchTerms.getKeywords(), groupParams, searchTerms.isAndOperator());
			}

			total += additionalSites;

			results.addAll(groups);

			pageContext.setAttribute("results", results);
			pageContext.setAttribute("total", total);
			%>

		</liferay-ui:search-container-results>

		<liferay-ui:search-container-row
			className="com.liferay.portal.model.Group"
			escapedModel="<%= true %>"
			keyProperty="groupId"
			modelVar="group"
			rowIdProperty="friendlyURL"
		>

			<%
			String rowHREF = null;

			if (!ArrayUtil.contains(selectedGroupIds, group.getGroupId())) {
				StringBundler sb = new StringBundler(11);

				sb.append("javascript:Liferay.Util.getOpener().");
				sb.append(Validator.isNotNull(callback) ? callback : "selectGroup");
				sb.append("('");
				sb.append(group.getGroupId());
				sb.append("', '");
				sb.append(UnicodeFormatter.toString(group.getDescriptiveName(locale)));
				sb.append("', '");
				sb.append(AssetPublisherUtil.getScopeId(group, scopeGroupId));
				sb.append("', '");
				sb.append(target);
				sb.append("'); Liferay.Util.getWindow().close();");

				rowHREF = sb.toString();
			}
			%>

			<liferay-ui:search-container-column-text
				href="<%= rowHREF %>"
				name="name"
				value="<%= HtmlUtil.escape(group.getDescriptiveName(locale)) %>"
			/>

			<liferay-ui:search-container-column-text
				href="<%= rowHREF %>"
				name="type"
				value="<%= LanguageUtil.get(pageContext, group.getTypeLabel()) %>"
			/>
		</liferay-ui:search-container-row>

		<liferay-ui:search-iterator />
	</liferay-ui:search-container>
</aui:form>

<aui:script>
	Liferay.Util.focusFormField(document.<portlet:namespace />fm.<portlet:namespace />name);
</aui:script>

<%!
private List<Group> _filterGroups(List<Group> groups, String filter) throws Exception {
	List<Group> filteredGroups = new ArrayList();

	for (Group group : groups) {
		if (filter.equals("contentSharingWithChildrenEnabled") && SitesUtil.isContentSharingWithChildrenEnabled(group)) {
			filteredGroups.add(group);
		}
	}

	return filteredGroups;
}
%>