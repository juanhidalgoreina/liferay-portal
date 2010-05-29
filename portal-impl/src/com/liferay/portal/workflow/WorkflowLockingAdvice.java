/**
 * Copyright (c) 2000-2010 Liferay, Inc. All rights reserved.
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

package com.liferay.portal.workflow;

import com.liferay.portal.kernel.util.StringPool;
import com.liferay.portal.kernel.util.Time;
import com.liferay.portal.kernel.workflow.WorkflowDefinition;
import com.liferay.portal.kernel.workflow.WorkflowException;
import com.liferay.portal.service.LockLocalServiceUtil;

import org.aspectj.lang.ProceedingJoinPoint;

/**
 * <a href="WorkflowLockingAdvice.java.html"><b><i>View Source</i></b></a>
 *
 * @author Shuyang Zhou
 * @author Brian Wing Shun Chan
 */
public class WorkflowLockingAdvice {

	public Object invoke(ProceedingJoinPoint proceedingJoinPoint)
		throws Throwable {

		String methodName = proceedingJoinPoint.getSignature().getName();
		Object[] arguments = proceedingJoinPoint.getArgs();

		if (methodName.equals(_START_WORKFLOW_INSTANCE_METHOD_NAME)) {
			String workflowDefinitionName = (String)arguments[3];
			Integer workflowDefinitionVersion = (Integer)arguments[4];

			String className = WorkflowDefinition.class.getName();
			String key = _encodeKey(
				workflowDefinitionName, workflowDefinitionVersion);

			if (LockLocalServiceUtil.isLocked(className, key)) {
				throw new WorkflowException(
					"Workflow definition name " + workflowDefinitionName +
						" and version " + workflowDefinitionVersion +
							" is being undeployed");
			}

			return proceedingJoinPoint.proceed();
		}
		else if (!methodName.equals(
					_UNDEPLOY_WORKFLOW_DEFINITION_METHOD_NAME)) {

			return proceedingJoinPoint.proceed();
		}

		long userId = (Long)arguments[1];
		String name = (String)arguments[2];
		Integer version = (Integer)arguments[3];

		String className = WorkflowDefinition.class.getName();
		String key = _encodeKey(name, version);

		if (LockLocalServiceUtil.isLocked(className, key)) {
			throw new WorkflowException(
				"Workflow definition name " + name + " and version " + version +
					" is being undeployed");
		}

		try {
			LockLocalServiceUtil.lock(
				userId, className, key, String.valueOf(userId), false,
				Time.HOUR);

			return proceedingJoinPoint.proceed();
		}
		finally {
			LockLocalServiceUtil.unlock(className, key);
		}
	}

	private String _encodeKey(String name, int version) {
		return name.concat(StringPool.POUND).concat(String.valueOf(version));
	}

	private static final String _START_WORKFLOW_INSTANCE_METHOD_NAME =
		"startWorkflowInstance";

	private static final String _UNDEPLOY_WORKFLOW_DEFINITION_METHOD_NAME =
		"undeployWorkflowDefinition";

}