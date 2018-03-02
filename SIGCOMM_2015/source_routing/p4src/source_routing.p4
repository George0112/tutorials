/*
Copyright 2013-present Barefoot Networks, Inc. 

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/


header_type ingress_intrinsic_metadata_t {
    fields {
        resubmit_flag : 1;              // flag distinguishing original packets
                                        // from resubmitted packets.

        ingress_global_timestamp : 48;     // global timestamp (ns) taken upon
                                        // arrival at ingress.

        mcast_grp : 16;                 // multicast group id (key for the
                                        // mcast replication table)

        deflection_flag : 1;            // flag indicating whether a packet is
                                        // deflected due to deflect_on_drop.
        deflect_on_drop : 1;            // flag indicating whether a packet can
                                        // be deflected by TM on congestion drop

        enq_congest_stat : 2;           // queue congestion status at the packet
                                        // enqueue time.

        deq_congest_stat : 2;           // queue congestion status at the packet
                                        // dequeue time.

        mcast_hash : 13;                // multicast hashing

        egress_rid : 16;                // Replication ID for multicast

        lf_field_list : 32;             // Learn filter field list

        priority : 3;                   // set packet priority

        ingress_cos: 3;                 // ingress cos

        packet_color: 2;                // packet color

        qid: 5;                         // queue id
    }
}

metadata ingress_intrinsic_metadata_t intrinsic_metadata;

header_type queueing_metadata_t {
    fields {
        enq_timestamp: 48;

        enq_qdepth: 16;

        deq_timedelta: 32;

        deq_qdepth: 16;

    }
}

metadata queueing_metadata_t queueing_metadata;

header_type ethernet_t {
	fields {
		dstAddr: 48;
		srcAddr: 48;
		etherType: 16;
	}
}

header ethernet_t ethernet;

header_type ipv4_t {
	fields {
		version: 4;
		ihl: 4;
		diffserv: 8;
		totalLen: 16;
		identification: 16;
		flags: 3;
		tragOffset: 13;
		ttl: 8;
		protocol: 8;
		hdrChecksum: 16;
		srcAddr: 32;
		dstAddr: 32;
	}

}

header ipv4_t ipv4;

header_type option_t {
	fields {
		optins: 24;
		padding: 8;
	}
}

header option_t option;

header_type udp_t {
	fields {
		src_port: 16;
		dst_port: 16;
		pkt_length: 16;
		checksum: 16;
	}
}

header udp_t udp;

header_type svef_t {
	fields {
		lid: 8;
		tid: 8;
		qid: 8;
		l: 1;
		ty: 2;
		d: 1;
		t: 1;
		two: 1;
		res: 2;
		naluid: 32;
		total_size: 16;
		frame_num: 16;
	}
}

header svef_t svef;

parser start {
    return parse_ethernet;
}

parser parse_ethernet {
	extract(ethernet);
	return parse_ipv4;
}

parser parse_ipv4 {
    extract(ipv4);
    return parse_option;
}

parser parse_option {
	extract(option);
	return parse_udp;
}

parser parse_udp {
	extract(udp);
	return parse_svef;
}

parser parse_svef {
	extract(svef);
	return ingress;
}

action _drop() {
    drop();
}

action route(port) {
	modify_field(standard_metadata.egress_spec, port);
	//ethernet.srcAddr = ipAddr;
	//ipv4.dstAddr == 0 ? modify_field(standard_metadata.egress_spec : modify_field(standard_metadata.egress_spec, 1);
}

action broadcast(mcast_group) {
	modify_field(intrinsic_metadata.mcast_grp, mcast_group);
}

table route_pkt {
    reads {
        ipv4.dstAddr: lpm;
    }
    actions {
        _drop;
        route;
		broadcast;
    }
    size: 3;
}

control ingress {
    apply(route_pkt);
}

control egress {
    // leave empty
}
