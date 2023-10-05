/*
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/* Automatically generated nanopb constant definitions */
/* Generated by nanopb-0.3.9.8 */

#include "common.nanopb.h"

#include "Firestore/core/src/nanopb/pretty_printing.h"

namespace firebase {
namespace firestore {

using nanopb::PrintEnumField;
using nanopb::PrintHeader;
using nanopb::PrintMessageField;
using nanopb::PrintPrimitiveField;
using nanopb::PrintTail;

/* @@protoc_insertion_point(includes) */
#if PB_PROTO_HEADER_VERSION != 30
#error Regenerate this file with the current version of nanopb generator.
#endif



const pb_field_t google_firestore_v1_DocumentMask_fields[2] = {
    PB_FIELD(  1, BYTES   , REPEATED, POINTER , FIRST, google_firestore_v1_DocumentMask, field_paths, field_paths, 0),
    PB_LAST_FIELD
};

const pb_field_t google_firestore_v1_Precondition_fields[3] = {
    PB_ANONYMOUS_ONEOF_FIELD(condition_type,   1, BOOL    , ONEOF, STATIC  , FIRST, google_firestore_v1_Precondition, exists, exists, 0),
    PB_ANONYMOUS_ONEOF_FIELD(condition_type,   2, MESSAGE , ONEOF, STATIC  , UNION, google_firestore_v1_Precondition, update_time, update_time, &google_protobuf_Timestamp_fields),
    PB_LAST_FIELD
};

const pb_field_t google_firestore_v1_TransactionOptions_fields[3] = {
    PB_ANONYMOUS_ONEOF_FIELD(mode,   2, MESSAGE , ONEOF, STATIC  , FIRST, google_firestore_v1_TransactionOptions, read_only, read_only, &google_firestore_v1_TransactionOptions_ReadOnly_fields),
    PB_ANONYMOUS_ONEOF_FIELD(mode,   3, MESSAGE , ONEOF, STATIC  , UNION, google_firestore_v1_TransactionOptions, read_write, read_write, &google_firestore_v1_TransactionOptions_ReadWrite_fields),
    PB_LAST_FIELD
};

const pb_field_t google_firestore_v1_TransactionOptions_ReadWrite_fields[2] = {
    PB_FIELD(  1, BYTES   , SINGULAR, POINTER , FIRST, google_firestore_v1_TransactionOptions_ReadWrite, retry_transaction, retry_transaction, 0),
    PB_LAST_FIELD
};

const pb_field_t google_firestore_v1_TransactionOptions_ReadOnly_fields[2] = {
    PB_ANONYMOUS_ONEOF_FIELD(consistency_selector,   2, MESSAGE , ONEOF, STATIC  , FIRST, google_firestore_v1_TransactionOptions_ReadOnly, read_time, read_time, &google_protobuf_Timestamp_fields),
    PB_LAST_FIELD
};


/* Check that field information fits in pb_field_t */
#if !defined(PB_FIELD_32BIT)
/* If you get an error here, it means that you need to define PB_FIELD_32BIT
 * compile-time option. You can do that in pb.h or on compiler command line.
 *
 * The reason you need to do this is that some of your messages contain tag
 * numbers or field sizes that are larger than what can fit in 8 or 16 bit
 * field descriptors.
 */
PB_STATIC_ASSERT((pb_membersize(google_firestore_v1_Precondition, update_time) < 65536 && pb_membersize(google_firestore_v1_TransactionOptions, read_only) < 65536 && pb_membersize(google_firestore_v1_TransactionOptions, read_write) < 65536 && pb_membersize(google_firestore_v1_TransactionOptions_ReadOnly, read_time) < 65536), YOU_MUST_DEFINE_PB_FIELD_32BIT_FOR_MESSAGES_google_firestore_v1_DocumentMask_google_firestore_v1_Precondition_google_firestore_v1_TransactionOptions_google_firestore_v1_TransactionOptions_ReadWrite_google_firestore_v1_TransactionOptions_ReadOnly)
#endif

#if !defined(PB_FIELD_16BIT) && !defined(PB_FIELD_32BIT)
/* If you get an error here, it means that you need to define PB_FIELD_16BIT
 * compile-time option. You can do that in pb.h or on compiler command line.
 *
 * The reason you need to do this is that some of your messages contain tag
 * numbers or field sizes that are larger than what can fit in the default
 * 8 bit descriptors.
 */
PB_STATIC_ASSERT((pb_membersize(google_firestore_v1_Precondition, update_time) < 256 && pb_membersize(google_firestore_v1_TransactionOptions, read_only) < 256 && pb_membersize(google_firestore_v1_TransactionOptions, read_write) < 256 && pb_membersize(google_firestore_v1_TransactionOptions_ReadOnly, read_time) < 256), YOU_MUST_DEFINE_PB_FIELD_16BIT_FOR_MESSAGES_google_firestore_v1_DocumentMask_google_firestore_v1_Precondition_google_firestore_v1_TransactionOptions_google_firestore_v1_TransactionOptions_ReadWrite_google_firestore_v1_TransactionOptions_ReadOnly)
#endif


std::string google_firestore_v1_DocumentMask::ToString(int indent) const {
    std::string tostring_header = PrintHeader(indent, "DocumentMask", this);
    std::string tostring_result;

    for (pb_size_t i = 0; i != field_paths_count; ++i) {
        tostring_result += PrintPrimitiveField("field_paths: ",
            field_paths[i], indent + 1, true);
    }

    bool is_root = indent == 0;
    if (!tostring_result.empty() || is_root) {
      std::string tostring_tail = PrintTail(indent);
      return tostring_header + tostring_result + tostring_tail;
    } else {
      return "";
    }
}

std::string google_firestore_v1_Precondition::ToString(int indent) const {
    std::string tostring_header = PrintHeader(indent, "Precondition", this);
    std::string tostring_result;

    switch (which_condition_type) {
    case google_firestore_v1_Precondition_exists_tag:
        tostring_result += PrintPrimitiveField("exists: ",
            exists, indent + 1, true);
        break;
    case google_firestore_v1_Precondition_update_time_tag:
        tostring_result += PrintMessageField("update_time ",
            update_time, indent + 1, true);
        break;
    }

    bool is_root = indent == 0;
    if (!tostring_result.empty() || is_root) {
      std::string tostring_tail = PrintTail(indent);
      return tostring_header + tostring_result + tostring_tail;
    } else {
      return "";
    }
}

std::string google_firestore_v1_TransactionOptions::ToString(int indent) const {
    std::string tostring_header = PrintHeader(indent, "TransactionOptions", this);
    std::string tostring_result;

    switch (which_mode) {
    case google_firestore_v1_TransactionOptions_read_only_tag:
        tostring_result += PrintMessageField("read_only ",
            read_only, indent + 1, true);
        break;
    case google_firestore_v1_TransactionOptions_read_write_tag:
        tostring_result += PrintMessageField("read_write ",
            read_write, indent + 1, true);
        break;
    }

    bool is_root = indent == 0;
    if (!tostring_result.empty() || is_root) {
      std::string tostring_tail = PrintTail(indent);
      return tostring_header + tostring_result + tostring_tail;
    } else {
      return "";
    }
}

std::string google_firestore_v1_TransactionOptions_ReadWrite::ToString(int indent) const {
    std::string tostring_header = PrintHeader(indent, "ReadWrite", this);
    std::string tostring_result;

    tostring_result += PrintPrimitiveField("retry_transaction: ",
        retry_transaction, indent + 1, false);

    bool is_root = indent == 0;
    if (!tostring_result.empty() || is_root) {
      std::string tostring_tail = PrintTail(indent);
      return tostring_header + tostring_result + tostring_tail;
    } else {
      return "";
    }
}

std::string google_firestore_v1_TransactionOptions_ReadOnly::ToString(int indent) const {
    std::string tostring_header = PrintHeader(indent, "ReadOnly", this);
    std::string tostring_result;

    switch (which_consistency_selector) {
    case google_firestore_v1_TransactionOptions_ReadOnly_read_time_tag:
        tostring_result += PrintMessageField("read_time ",
            read_time, indent + 1, true);
        break;
    }

    bool is_root = indent == 0;
    if (!tostring_result.empty() || is_root) {
      std::string tostring_tail = PrintTail(indent);
      return tostring_header + tostring_result + tostring_tail;
    } else {
      return "";
    }
}

}  // namespace firestore
}  // namespace firebase

/* @@protoc_insertion_point(eof) */
