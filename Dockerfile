FROM python:3

ENV TZ=America/Chicago
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

WORKDIR /srv
COPY bin bin/
COPY conf conf/
COPY lib lib/
COPY requirements.txt ./
COPY jira_cleanup jira_cleanup/
COPY wiki_cleanup wiki_cleanup/
RUN python -m pip install -r /srv/requirements.txt
RUN ln -s /home/.netrc /root/.netrc
RUN ln -s /home/.atlassian-tools-config.ini /root/.atlassian-tools-config.ini

CMD ["bash"]
