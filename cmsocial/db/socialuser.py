# -*- coding: utf-8 -*-

"""User-related database interface for SQLAlchemy.

"""

from __future__ import absolute_import
from __future__ import print_function
from __future__ import unicode_literals

from datetime import timedelta, datetime

from sqlalchemy.schema import Column, ForeignKey, CheckConstraint
from sqlalchemy.types import Boolean, Integer, String, Unicode, DateTime, \
    Interval
from sqlalchemy.orm import relationship, backref

from cms.db import Base, Contest

# CUSTOM FIELDS:
from cmsocial.db.location import Institute


class SocialUser(Base):
    """Class to store stats and custom fields (institute_id?) of a user.

    """
    __tablename__ = 'social_users'

    # User.id == SocialUser.id
    id = Column(
        Integer,
        ForeignKey("users.id",
            onupdate="CASCADE",
            ondelete="CASCADE"
        ),
        primary_key=True
    )

    user = relationship(
        "User",
        backref=backref(
            "social_user",
            uselist=False
        )
    )

    # Access level
    access_level = Column(
        Integer,
        nullable=False,
        default=6
    )

    # Score
    score = Column(
        Integer,
        nullable=False,
        default=0
    )

    registration_time = Column(
        DateTime,
        nullable=False,
        default=datetime.utcnow()
    )

    # The last time this user requested a testcase
    last_help_time = Column(
        DateTime,
        nullable=False,
        default=datetime.utcfromtimestamp(0)
    )

    # Total number of helps received
    help_count = Column(
        Integer,
        nullable=False,
        default=0
    )

    # CUSTOM FIELDS:

    # Institute
    institute_id = Column(
        Integer,
        ForeignKey(
            Institute.id,
            onupdate="CASCADE",
            ondelete="SET NULL"
        ),
        nullable=True,
        index=True
    )

    institute = relationship(
        Institute,
        backref=backref(
            "users",
            cascade="all, delete-orphan",
            passive_deletes=True
        )
    )

    # List of tasktags (not "approved" yet) created by this user
    # FIXME: the following causes a circular dependency
    # tasktags = relationship("TaskTag")
