use strict;
use warnings;

use Test::More;
use Plack::Test;
use Plack::Util;
use HTTP::Request::Common;
use JSON::MaybeXS qw(decode_json encode_json);
use File::Temp qw(tempdir);
use Path::Tiny qw(path);

my $tmpdir = tempdir( CLEANUP => 1 );
my $db_file = path($tmpdir)->child('todo.json');
$ENV{TODO_DB} = $db_file;
my $ELAPSED = qr{^\d+\.\d+$};

my %data = (
    "123" => "Hello world",
    "124" => "Something else",
    "738" => "A 3rd row",
);


my $app = Plack::Util::load_psgi './app.psgi';

subtest main => sub {
    my $test = Plack::Test->create($app);
    my $res = $test->request(GET '/');

    is $res->status_line, '200 OK', 'Status';
    is $res->content, 'TODO', 'content of HTML page';
};



subtest add_first => sub {
    my $test = Plack::Test->create($app);

    my $text = 'First item';
    my $res_add = $test->request(GET "/api/add/$text");
    is $res_add->status_line, '200 OK', 'Status';
    diag $res_add->content;
    my $resp_add = decode_json($res_add->content);
    is $resp_add->{status}, "ok", 'status field exists';
    like $resp_add->{elapsed}, $ELAPSED, 'elapsed field looks good';
    my $id = $resp_add->{id};
    like $id, qr{^\d{8,}$}, 'id looks good';
    diag $id;

    my $json = decode_json(path($db_file)->slurp);
    is_deeply $json, { $id => $text };
};

# TODO add_more

subtest good_get => sub {
    my $test = Plack::Test->create($app);

    my $id = '123';

    path($db_file)->spew(encode_json(\%data));
    my $res_add = $test->request(GET "/api/get/$id");
    is $res_add->status_line, '200 OK', 'Status';
    diag $res_add->content;
    my $resp = decode_json($res_add->content);
    like $resp->{elapsed}, $ELAPSED, 'elapsed';
    delete $resp->{elapsed};
    is_deeply $resp, { "status" => "ok", text => $data{$id}, id => $id }, 'returned json data';

    my $json = decode_json(path($db_file)->slurp);
    is_deeply $json, \%data;
};

subtest bad_get => sub {
    my $test = Plack::Test->create($app);

    my $id = '42';

    path($db_file)->spew(encode_json(\%data));
    my $res_add = $test->request(GET "/api/get/$id");
    is $res_add->status_line, '404 Not Found', 'Status';
    diag $res_add->content;
    my $resp = decode_json($res_add->content);
    like $resp->{elapsed}, $ELAPSED, 'elapsed';
    delete $resp->{elapsed};
    is_deeply $resp, { "status" => "failure", id => $id }, 'returned json data';

    my $json = decode_json(path($db_file)->slurp);
    is_deeply $json, \%data;
};


subtest bad_del => sub {
    my $test = Plack::Test->create($app);

    my $id = '42';

    path($db_file)->spew(encode_json(\%data));
    my $res_add = $test->request(GET "/api/get/$id");
    is $res_add->status_line, '404 Not Found', 'Status';
    diag $res_add->content;
    my $resp = decode_json($res_add->content);
    like $resp->{elapsed}, $ELAPSED, 'elapsed';
    delete $resp->{elapsed};
    is_deeply $resp, { "status" => "failure", id => $id }, 'returned json data';

    my $json = decode_json(path($db_file)->slurp);
    is_deeply $json, \%data;
};


#* `/api/list`                  will return the list of all the items with their id: {[ { "text": "Task to do", "id": "13124" }, { "text": "Other thing", "id" : "7238" }], elapsed: "0.0004", "status": "ok" }
#* `/api/del/ID                 will remove the given task from the database. Will return {"status": "ok"} if managed to remove, will return {"status": "failure"} if failed. (e.g. the item was not in the database)


#subtest various => sub {
#    my $test = Plack::Test->create($app);
#
#    my $res_add = $test->request(GET '/api/add/First item');
#    is $res_add->status_line, '200 OK', 'Status';
#    diag $res_add->content;
#    my $resp_add = decode_json($res_add->content);
#    is $resp_add->{status}, "ok", 'status field exists';
#    like $resp_add->{elapsed}, qr{^\d+\.\d+$}, 'elapsed field looks good';
#    my $id = $resp_add->{id};
#    like $id, qr{^\d{8,}$}, 'id looks good';
#    diag $id;
#
#
#
#
#    my @cases = ('Something todo', 'Another item');
#    for my $case (@cases) {
#        my $res = $test->request(GET "/api/add/$case");
#        is $res->status_line, '200 OK', 'Status';
#    }
#
#};


done_testing();
