FROM --platform=linux/amd64 ubuntu:xenial

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN set -x; \
        apt-get update \
        && apt-get install -y --no-install-recommends apt-transport-https ca-certificates gnupg \
            ca-certificates \
            curl \
            wget \
            dirmngr \
            node-less \
            python-dateutil python-docutils python-feedparser \
            python-ldap python-libxslt1 python-lxml \
            python-mako python-mock python-openid python-psycopg2 python-psutil python-pybabel python-pychart python-pydot \ 
            python-pyparsing python-reportlab python-simplejson python-tz python-unittest2 python-vatnumber python-vobject \
            python-webdav python-werkzeug python-xlwt python-yaml python-zsi poppler-utils python-pip python-pypdf \
            python-passlib python-decorator gcc python-dev mc bzr python-setuptools python-markupsafe python-reportlab-accel \
            python-zsi python-yaml python-argparse python-openssl python-egenix-mxdatetime python-usb python-serial lptools \
            make python-pydot python-psutil python-paramiko poppler-utils python-pdftools antiword python-requests \
            python-xlsxwriter python-suds python-psycogreen python-ofxparse python-gevent  python-imaging python-jinja2
RUN curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.xenial_amd64.deb \
        && echo '61a1e5cf4f63ba1bc517ddf18a7d8fd95973f717 wkhtmltox.deb' | sha1sum -c - \
        && dpkg --force-depends -i wkhtmltox.deb \
        && apt-get -y install -f --no-install-recommends \
        && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false npm \
        && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null
RUN set -x; 

RUN apt-get update \
&& apt-get -y install postgresql

RUN adduser --system --home=/opt/odoo --group odoo
WORKDIR /opt/odoo
RUN mkdir /var/lib/odoo && chown odoo /var/lib/odoo
RUN mkdir /var/log/odoo && chown odoo /var/log/odoo

RUN pip install --upgrade pip==9.0.3
RUN pip install --upgrade pip==18.0
RUN pip install --upgrade pip
# RUN pip install virtualenv

USER odoo
# RUN virtualenv /opt/odoo/ve
# RUN  . /opt/odoo/ve/bin/activate

RUN pip install psycogreen==1.0
RUN pip install num2words
RUN pip install --upgrade wheel
RUN pip install numpy==1.16.6 --user
RUN pip install Cython==0.29 --install-option="--no-cython-compile" --user
RUN pip install pandas==0.24.2 --user
RUN pip install xlsxwriter==0.7.3

USER root
# Install Odoo
ENV ODOO_VERSION 10.0
ARG ODOO_RELEASE=latest
ARG ODOO_SHA=db5d5f6fb4141aa62cd8ca6f82d30b27e4393dc5
RUN set -x; \
        curl -o odoo.deb -sSL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_${ODOO_VERSION}.${ODOO_RELEASE}_all.deb \
        && echo "${ODOO_SHA} odoo.deb" | sha1sum -c -
RUN dpkg --force-depends -i odoo.deb \
        && apt-get update \
        && apt-get -y install -f --no-install-recommends \
        && rm -rf /var/lib/apt/lists/* odoo.deb

# Copy entrypoint script and Odoo configuration file
COPY ./entrypoint.sh /usr/local/bin/
RUN ["chmod", "+x", "/usr/local/bin/entrypoint.sh"]
COPY ./odoo.conf /etc/odoo/
RUN chown odoo /etc/odoo/odoo.conf

# Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN mkdir -p /mnt/extra-addons \
        && chown -R odoo /mnt/extra-addons
VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Expose Odoo services
EXPOSE 8069 8071

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

# Set default user when running the container
USER odoo
ENV PATH="/opt/odoo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["odoo"]