################################################################################################
## Build wpCloud Container(s)
##
################################################################################################

CODEBASE_PATH                 ?=/opt/sources/wpCloud/git-docker
DEPLOY_TARGET		            	?=core@amarah.wpcloud.io
CURRENT_BRANCH                ?=$(shell git describe --contains --all HEAD)
CURRENT_COMMIT                ?=$(shell git rev-list -1 HEAD)
CURRENT_TAG                   ?=$(shell git describe --always --tag)
DEPLOYED_BRANCH								?=$(shell ssh ${DEPLOY_TARGET} 'git --git-dir=/opt/sources/wpCloud/git-docker/.git --work-tree=/opt/sources/wpCloud/git-docker rev-parse --abbrev-ref HEAD')
DEPLOYED_COMMIT								?=$(shell ssh ${DEPLOY_TARGET} 'git --git-dir=/opt/sources/wpCloud/git-docker/.git --work-tree=/opt/sources/wpCloud/git-docker rev-list -1 HEAD')
DEPLOYED_TAG									?=$(shell ssh ${DEPLOY_TARGET} 'git --git-dir=/opt/sources/wpCloud/git-docker/.git --work-tree=/opt/sources/wpCloud/git-docker describe --always --tag')


## Handle Docker Deployment to Ramadi
##
deployment:
	@echo "Deployed branch appears to be [${DEPLOYED_BRANCH}] with tag [${DEPLOYED_TAG}]."
	@ssh ${DEPLOY_TARGET} "git --git-dir=/opt/sources/wpCloud/git-docker/.git --work-tree=/opt/sources/wpCloud/git-docker fetch origin -q"
	@ssh ${DEPLOY_TARGET} 'git --git-dir=/opt/sources/wpCloud/git-docker/.git --work-tree=/opt/sources/wpCloud/git-docker checkout ${DEPLOYED_BRANCH} -q'
	@ssh ${DEPLOY_TARGET} "git --git-dir=/opt/sources/wpCloud/git-docker/.git --work-tree=/opt/sources/wpCloud/git-docker reset --hard origin/${DEPLOYED_BRANCH} -q"
	@ssh ${DEPLOY_TARGET} "git --git-dir=/opt/sources/wpCloud/git-docker/.git --work-tree=/opt/sources/wpCloud/git-docker clean -fdq"
	@echo "Production deployment done, commit went from [${DEPLOYED_COMMIT}] to [$(shell ssh ${DEPLOY_TARGET})]."

